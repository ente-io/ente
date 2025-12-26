pub mod argon2;
pub mod auth_flow;
pub mod hash;
pub mod kdf;
pub mod sealed;
pub mod secretbox;
pub mod stream;

/// Test result: (passed, failed)
pub type TestResult = (usize, usize);

/// Run a single test, print result, return success
pub fn run_test(name: &str, test_fn: impl FnOnce() -> bool) -> bool {
    let result = test_fn();
    let status = if result { "✓" } else { "✗" };
    println!("  {status} {name}");
    result
}

/// Helper macro for running multiple tests
#[macro_export]
macro_rules! run_tests {
    ($($name:expr => $test:expr),* $(,)?) => {{
        let mut passed = 0;
        let mut failed = 0;
        $(
            if $crate::tests::run_test($name, || $test) {
                passed += 1;
            } else {
                failed += 1;
            }
        )*
        (passed, failed)
    }};
}
