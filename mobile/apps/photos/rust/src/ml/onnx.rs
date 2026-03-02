use ort::{
    CPUExecutionProvider, ExecutionProviderDispatch, GraphOptimizationLevel, Session, Tensor,
    XNNPACKExecutionProvider,
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

pub fn run_f32<const N: usize>(
    session: &mut Session,
    input: Vec<f32>,
    input_shape: [i64; N],
) -> MlResult<(Vec<i64>, Vec<f32>)> {
    let input_tensor = Tensor::<f32>::from_array((input_shape, input))?;
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

pub fn run_f32_data<const N: usize>(
    session: &mut Session,
    input: Vec<f32>,
    input_shape: [i64; N],
) -> MlResult<Vec<f32>> {
    let input_tensor = Tensor::<f32>::from_array((input_shape, input))?;
    let outputs = session.run(ort::inputs![input_tensor]?)?;
    if outputs.is_empty() {
        return Err(MlError::Ort("missing first output tensor".to_string()));
    }
    let output = &outputs[0];
    let tensor = output.try_extract_tensor::<f32>()?;
    Ok(tensor.iter().copied().collect::<Vec<_>>())
}
