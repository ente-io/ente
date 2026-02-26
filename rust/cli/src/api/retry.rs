use crate::Result;
use reqwest::{Response, StatusCode};
use std::time::Duration;
use tokio::time::sleep;

/// Retry configuration
pub struct RetryConfig {
    pub max_retries: u32,
    pub initial_delay: Duration,
    pub max_delay: Duration,
    pub exponential_base: f64,
}

impl Default for RetryConfig {
    fn default() -> Self {
        Self {
            max_retries: 3,
            initial_delay: Duration::from_millis(500),
            max_delay: Duration::from_secs(30),
            exponential_base: 2.0,
        }
    }
}

/// Execute a request with retry logic
pub async fn with_retry<F, Fut>(config: &RetryConfig, mut operation: F) -> Result<Response>
where
    F: FnMut() -> Fut,
    Fut: std::future::Future<Output = Result<Response>>,
{
    let mut attempt = 0;
    let mut delay = config.initial_delay;

    loop {
        match operation().await {
            Ok(response) => {
                // Check if we should retry based on status code
                let status = response.status();

                if status.is_success() {
                    return Ok(response);
                }

                // Don't retry on client errors (except 429)
                if status.is_client_error() && status != StatusCode::TOO_MANY_REQUESTS {
                    return Ok(response);
                }

                // Retry on 429 (rate limited) or 5xx errors
                if status == StatusCode::TOO_MANY_REQUESTS || status.is_server_error() {
                    attempt += 1;

                    if attempt > config.max_retries {
                        log::warn!("Max retries ({}) exceeded for request", config.max_retries);
                        return Ok(response);
                    }

                    // Check for Retry-After header on 429 responses
                    if status == StatusCode::TOO_MANY_REQUESTS
                        && let Some(retry_after) = response.headers().get("retry-after")
                        && let Ok(retry_str) = retry_after.to_str()
                        && let Ok(seconds) = retry_str.parse::<u64>()
                    {
                        delay = Duration::from_secs(seconds);
                        log::info!("Rate limited, retrying after {} seconds", seconds);
                    }

                    log::info!(
                        "Request failed with status {}, retrying in {:?} (attempt {}/{})",
                        status,
                        delay,
                        attempt,
                        config.max_retries
                    );

                    sleep(delay).await;

                    // Calculate next delay with exponential backoff
                    delay = Duration::from_secs_f64(
                        (delay.as_secs_f64() * config.exponential_base)
                            .min(config.max_delay.as_secs_f64()),
                    );

                    continue;
                }

                // For other status codes, don't retry
                return Ok(response);
            }
            Err(e) => {
                // Network errors should be retried
                attempt += 1;

                if attempt > config.max_retries {
                    log::error!("Max retries ({}) exceeded: {}", config.max_retries, e);
                    return Err(e);
                }

                log::warn!(
                    "Request failed: {}, retrying in {:?} (attempt {}/{})",
                    e,
                    delay,
                    attempt,
                    config.max_retries
                );

                sleep(delay).await;

                // Calculate next delay with exponential backoff
                delay = Duration::from_secs_f64(
                    (delay.as_secs_f64() * config.exponential_base)
                        .min(config.max_delay.as_secs_f64()),
                );
            }
        }
    }
}
