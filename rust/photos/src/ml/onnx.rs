use ort::{
    CPUExecutionProvider, ExecutionProviderDispatch, GraphOptimizationLevel, Session, Tensor,
    TensorElementType, ValueType, XNNPACKExecutionProvider,
};

// Temporarily disabled on Rust side to avoid iOS duplicate ObjC class collisions
// (`CoreMLExecution`) while Dart ONNXRuntime is still linked in production.
// Re-enable once iOS uses a single shared ORT runtime.
// #[cfg(target_vendor = "apple")]
// use ort::CoreMLExecutionProvider;
#[cfg(target_os = "android")]
use ort::NNAPIExecutionProvider;

use crate::ml::{
    error::{MlError, MlResult},
    runtime::ExecutionProviderPolicy,
};

pub fn build_session(model_path: &str, policy: &ExecutionProviderPolicy) -> MlResult<Session> {
    let primary_providers = providers_for_policy(policy, true);
    let mut attempts = vec![primary_providers];

    if policy.allow_cpu_fallback && policy.prefer_xnnpack {
        let providers_without_xnnpack = providers_for_policy(policy, false);
        attempts.push(providers_without_xnnpack);
    }

    if policy.allow_cpu_fallback {
        let cpu_only_policy = ExecutionProviderPolicy {
            prefer_coreml: false,
            prefer_nnapi: false,
            prefer_xnnpack: false,
            allow_cpu_fallback: true,
        };
        let cpu_only_providers = providers_for_policy(&cpu_only_policy, false);
        attempts.push(cpu_only_providers);
    }

    let mut errors = Vec::new();
    for providers in attempts {
        if providers.is_empty() {
            continue;
        }

        match build_session_with_providers(model_path, providers) {
            Ok(session) => return Ok(session),
            Err(error) => errors.push(format!("{error}")),
        }
    }

    if errors.is_empty() {
        return Err(MlError::InvalidRequest(
            "no supported execution provider selected for this platform while CPU fallback is disabled"
                .to_string(),
        ));
    }

    Err(MlError::Ort(format!(
        "failed to create ONNX session for model '{model_path}' across EP fallbacks: {}",
        errors.join(" | ")
    )))
}

fn providers_for_policy(
    policy: &ExecutionProviderPolicy,
    include_xnnpack: bool,
) -> Vec<ExecutionProviderDispatch> {
    let mut providers: Vec<ExecutionProviderDispatch> = Vec::new();

    // Temporarily disabled on Rust side. Keep this block for easy re-enable.
    // #[cfg(target_vendor = "apple")]
    // if policy.prefer_coreml {
    //     providers.push(CoreMLExecutionProvider::default().build());
    // }

    #[cfg(target_os = "android")]
    if policy.prefer_nnapi {
        // Prefer NNAPI accelerators and let ORT handle CPU fallback via the added CPU EP.
        providers.push(NNAPIExecutionProvider::default().with_disable_cpu().build());
    }

    if policy.allow_cpu_fallback {
        if include_xnnpack && policy.prefer_xnnpack {
            providers.push(XNNPACKExecutionProvider::default().build());
        }
        providers.push(
            CPUExecutionProvider::default()
                .with_arena_allocator()
                .build(),
        );
    }

    providers
}

fn build_session_with_providers(
    model_path: &str,
    providers: Vec<ExecutionProviderDispatch>,
) -> MlResult<Session> {
    let mut builder = Session::builder()?
        .with_optimization_level(GraphOptimizationLevel::Level3)?
        .with_intra_threads(1)?
        .with_inter_threads(1)?;

    builder = builder.with_execution_providers(providers)?;

    let session = builder.commit_from_file(model_path)?;
    Ok(session)
}

/// Returns true if the session's first input expects FP16 tensors.
fn session_expects_f16(session: &Session) -> bool {
    session
        .inputs
        .first()
        .and_then(|i| match &i.input_type {
            ValueType::Tensor { ty, .. } => Some(*ty == TensorElementType::Float16),
            _ => None,
        })
        .unwrap_or(false)
}

/// Run inference accepting f32 data and returning f32 results.
/// Automatically converts inputs/outputs for FP16 models.
pub fn run_f32<const N: usize>(
    session: &Session,
    input: Vec<f32>,
    input_shape: [i64; N],
) -> MlResult<(Vec<i64>, Vec<f32>)> {
    let outputs = if session_expects_f16(session) {
        let f16_input: Vec<half::f16> = input.into_iter().map(half::f16::from_f32).collect();
        let input_tensor = Tensor::<half::f16>::from_array((input_shape, f16_input))?;
        session.run(ort::inputs![input_tensor]?)?
    } else {
        let input_tensor = Tensor::<f32>::from_array((input_shape, input))?;
        session.run(ort::inputs![input_tensor]?)?
    };

    if outputs.is_empty() {
        return Err(MlError::Ort("missing first output tensor".to_string()));
    }
    let output = &outputs[0];

    // Extract output: try f32 first, fall back to f16 with conversion.
    if let Ok(tensor) = output.try_extract_tensor::<f32>() {
        let shape = tensor.shape().iter().map(|d| *d as i64).collect::<Vec<_>>();
        let data = tensor.iter().copied().collect::<Vec<_>>();
        Ok((shape, data))
    } else {
        let tensor = output.try_extract_tensor::<half::f16>()?;
        let shape = tensor.shape().iter().map(|d| *d as i64).collect::<Vec<_>>();
        let data = tensor
            .iter()
            .map(|v: &half::f16| v.to_f32())
            .collect::<Vec<_>>();
        Ok((shape, data))
    }
}

pub fn run_f32_data<const N: usize>(
    session: &Session,
    input: Vec<f32>,
    input_shape: [i64; N],
) -> MlResult<Vec<f32>> {
    let outputs = if session_expects_f16(session) {
        let f16_input: Vec<half::f16> = input.into_iter().map(half::f16::from_f32).collect();
        let input_tensor = Tensor::<half::f16>::from_array((input_shape, f16_input))?;
        session.run(ort::inputs![input_tensor]?)?
    } else {
        let input_tensor = Tensor::<f32>::from_array((input_shape, input))?;
        session.run(ort::inputs![input_tensor]?)?
    };
    if outputs.is_empty() {
        return Err(MlError::Ort("missing first output tensor".to_string()));
    }
    let output = &outputs[0];
    if let Ok(tensor) = output.try_extract_tensor::<f32>() {
        Ok(tensor.iter().copied().collect::<Vec<_>>())
    } else {
        let tensor = output.try_extract_tensor::<half::f16>()?;
        Ok(tensor
            .iter()
            .map(|v: &half::f16| v.to_f32())
            .collect::<Vec<_>>())
    }
}

pub fn run_i32_f32<const N: usize>(
    session: &Session,
    input: Vec<i32>,
    input_shape: [i64; N],
) -> MlResult<(Vec<i64>, Vec<f32>)> {
    let input_tensor = Tensor::<i32>::from_array((input_shape, input))?;
    let outputs = session.run(ort::inputs![input_tensor]?)?;
    if outputs.is_empty() {
        return Err(MlError::Ort("missing first output tensor".to_string()));
    }
    let output = &outputs[0];
    let tensor = output.try_extract_tensor::<f32>()?;
    let shape = tensor.shape().iter().map(|d| *d as i64).collect::<Vec<_>>();
    let data = tensor.iter().copied().collect::<Vec<_>>();
    Ok((shape, data))
}
