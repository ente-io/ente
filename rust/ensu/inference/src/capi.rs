use crate::api::{
    self, ChatMessage, ContextHandleRef, GenerateChatRequest, GenerateEvent, GenerateRequest,
    GenerateSummary, ModelHandleRef,
};
use serde::Serialize;
use std::ffi::{CStr, CString};
use std::os::raw::{c_char, c_void};
use std::panic::{catch_unwind, AssertUnwindSafe};
use std::ptr;

#[repr(C)]
pub struct inference_model {
    handle: ModelHandleRef,
}

#[repr(C)]
pub struct inference_context {
    handle: ContextHandleRef,
}

type EventCallback = Option<extern "C" fn(*const u8, usize, *mut c_void)>;

#[derive(Serialize)]
#[serde(tag = "type", rename_all = "snake_case")]
enum CapiEvent {
    Text {
        job_id: api::JobId,
        text: String,
        token_id: Option<i32>,
    },
    Done { summary: GenerateSummary },
    Error {
        job_id: api::JobId,
        message: String,
    },
}

impl From<GenerateEvent> for CapiEvent {
    fn from(value: GenerateEvent) -> Self {
        match value {
            GenerateEvent::Text {
                job_id,
                text,
                token_id,
            } => Self::Text {
                job_id,
                text,
                token_id,
            },
            GenerateEvent::Done { summary } => Self::Done { summary },
            GenerateEvent::Error { job_id, message } => Self::Error { job_id, message },
        }
    }
}

struct CapiEventSink {
    callback: EventCallback,
    user_data: *mut c_void,
}

impl api::EventSink for CapiEventSink {
    fn add(&mut self, event: GenerateEvent) {
        let Some(callback) = self.callback else {
            return;
        };

        let payload = CapiEvent::from(event);
        let json = serde_json::to_vec(&payload)
            .unwrap_or_else(|_| br#"{"type":"error","message":"serialization_failed"}"#.to_vec());
        callback(json.as_ptr(), json.len(), self.user_data);
    }
}

fn clear_error(error_out: *mut *mut c_char) {
    if error_out.is_null() {
        return;
    }
    unsafe {
        *error_out = ptr::null_mut();
    }
}

fn set_error(error_out: *mut *mut c_char, message: impl AsRef<str>) {
    if error_out.is_null() {
        return;
    }
    let message = message.as_ref();
    let cstring = CString::new(message).unwrap_or_else(|_| CString::new("invalid error").unwrap());
    unsafe {
        *error_out = cstring.into_raw();
    }
}

fn with_error<T>(error_out: *mut *mut c_char, result: Result<T, String>) -> Option<T> {
    match result {
        Ok(value) => {
            clear_error(error_out);
            Some(value)
        }
        Err(err) => {
            set_error(error_out, err);
            None
        }
    }
}

fn cstr_to_string(ptr: *const c_char, field: &str) -> Result<String, String> {
    if ptr.is_null() {
        return Err(format!("{field} is required"));
    }
    let cstr = unsafe { CStr::from_ptr(ptr) };
    cstr.to_str()
        .map(|value| value.to_string())
        .map_err(|err| format!("Invalid {field}: {err}"))
}

fn optional_cstr(ptr: *const c_char) -> Result<Option<String>, String> {
    if ptr.is_null() {
        return Ok(None);
    }
    let cstr = unsafe { CStr::from_ptr(ptr) };
    let value = cstr
        .to_str()
        .map_err(|err| format!("Invalid string: {err}"))?;
    if value.is_empty() {
        Ok(None)
    } else {
        Ok(Some(value.to_string()))
    }
}

fn parse_json<T>(json_ptr: *const c_char, field: &str) -> Result<T, String>
where
    T: serde::de::DeserializeOwned,
{
    let json = cstr_to_string(json_ptr, field)?;
    serde_json::from_str(&json).map_err(|err| format!("Invalid {field} JSON: {err}"))
}

fn to_json_string<T: Serialize>(value: &T) -> Result<*mut c_char, String> {
    let json = serde_json::to_string(value).map_err(|err| err.to_string())?;
    CString::new(json)
        .map_err(|err| err.to_string())
        .map(|value| value.into_raw())
}

#[unsafe(no_mangle)]
pub extern "C" fn inference_string_free(value: *mut c_char) {
    if value.is_null() {
        return;
    }
    unsafe {
        drop(CString::from_raw(value));
    }
}

#[unsafe(no_mangle)]
pub extern "C" fn inference_init_backend(error_out: *mut *mut c_char) -> bool {
    let result = catch_unwind(AssertUnwindSafe(|| api::init_backend()));
    let result = match result {
        Ok(inner) => inner,
        Err(_) => Err("init_backend panicked".to_string()),
    };
    with_error(error_out, result).is_some()
}

#[unsafe(no_mangle)]
pub extern "C" fn inference_load_model(
    params_json: *const c_char,
    error_out: *mut *mut c_char,
) -> *mut inference_model {
    let result = catch_unwind(AssertUnwindSafe(|| {
        let params = parse_json::<api::ModelLoadParams>(params_json, "params_json")?;
        api::load_model(params)
    }));

    let result = match result {
        Ok(inner) => inner,
        Err(_) => Err("load_model panicked".to_string()),
    };

    let Some(handle) = with_error(error_out, result) else {
        return ptr::null_mut();
    };

    Box::into_raw(Box::new(inference_model { handle }))
}

#[unsafe(no_mangle)]
pub extern "C" fn inference_model_free(model: *mut inference_model) {
    if model.is_null() {
        return;
    }
    unsafe {
        drop(Box::from_raw(model));
    }
}

#[unsafe(no_mangle)]
pub extern "C" fn inference_create_context(
    model: *const inference_model,
    params_json: *const c_char,
    error_out: *mut *mut c_char,
) -> *mut inference_context {
    let result = catch_unwind(AssertUnwindSafe(|| {
        let model = unsafe { model.as_ref() }.ok_or_else(|| "model is required".to_string())?;
        let params = parse_json::<api::ContextParams>(params_json, "params_json")?;
        api::create_context(model.handle.clone(), params)
    }));

    let result = match result {
        Ok(inner) => inner,
        Err(_) => Err("create_context panicked".to_string()),
    };

    let Some(handle) = with_error(error_out, result) else {
        return ptr::null_mut();
    };

    Box::into_raw(Box::new(inference_context { handle }))
}

#[unsafe(no_mangle)]
pub extern "C" fn inference_context_free(context: *mut inference_context) {
    if context.is_null() {
        return;
    }
    unsafe {
        drop(Box::from_raw(context));
    }
}

#[unsafe(no_mangle)]
pub extern "C" fn inference_tokenize_json(
    model: *const inference_model,
    text: *const c_char,
    add_bos: bool,
    special: bool,
    error_out: *mut *mut c_char,
) -> *mut c_char {
    let result = catch_unwind(AssertUnwindSafe(|| {
        let model = unsafe { model.as_ref() }.ok_or_else(|| "model is required".to_string())?;
        let text = cstr_to_string(text, "text")?;
        let tokens = api::tokenize(model.handle.as_ref(), text, add_bos, special)?;
        to_json_string(&tokens)
    }));

    let result = match result {
        Ok(inner) => inner,
        Err(_) => Err("tokenize panicked".to_string()),
    };

    with_error(error_out, result).unwrap_or(ptr::null_mut())
}

#[unsafe(no_mangle)]
pub extern "C" fn inference_detokenize_json(
    model: *const inference_model,
    tokens_json: *const c_char,
    error_out: *mut *mut c_char,
) -> *mut c_char {
    let result = catch_unwind(AssertUnwindSafe(|| {
        let model = unsafe { model.as_ref() }.ok_or_else(|| "model is required".to_string())?;
        let tokens = parse_json::<Vec<i32>>(tokens_json, "tokens_json")?;
        let text = api::detokenize(model.handle.as_ref(), tokens)?;
        to_json_string(&text)
    }));

    let result = match result {
        Ok(inner) => inner,
        Err(_) => Err("detokenize panicked".to_string()),
    };

    with_error(error_out, result).unwrap_or(ptr::null_mut())
}

#[unsafe(no_mangle)]
pub extern "C" fn inference_get_model_info_json(
    model: *const inference_model,
    error_out: *mut *mut c_char,
) -> *mut c_char {
    let result = catch_unwind(AssertUnwindSafe(|| {
        let model = unsafe { model.as_ref() }.ok_or_else(|| "model is required".to_string())?;
        let info = api::get_model_info(model.handle.as_ref())?;
        to_json_string(&info)
    }));

    let result = match result {
        Ok(inner) => inner,
        Err(_) => Err("get_model_info panicked".to_string()),
    };

    with_error(error_out, result).unwrap_or(ptr::null_mut())
}

#[unsafe(no_mangle)]
pub extern "C" fn inference_apply_chat_template_json(
    model: *const inference_model,
    messages_json: *const c_char,
    template_override: *const c_char,
    add_assistant: bool,
    error_out: *mut *mut c_char,
) -> *mut c_char {
    let result = catch_unwind(AssertUnwindSafe(|| {
        let model = unsafe { model.as_ref() }.ok_or_else(|| "model is required".to_string())?;
        let messages = parse_json::<Vec<ChatMessage>>(messages_json, "messages_json")?;
        let template_override = optional_cstr(template_override)?;
        let rendered = api::apply_chat_template(
            model.handle.as_ref(),
            messages,
            template_override,
            add_assistant,
        )?;
        to_json_string(&rendered)
    }));

    let result = match result {
        Ok(inner) => inner,
        Err(_) => Err("apply_chat_template panicked".to_string()),
    };

    with_error(error_out, result).unwrap_or(ptr::null_mut())
}

#[unsafe(no_mangle)]
pub extern "C" fn inference_generate_chat_stream(
    context: *const inference_context,
    request_json: *const c_char,
    callback: EventCallback,
    user_data: *mut c_void,
    error_out: *mut *mut c_char,
) -> bool {
    let result = catch_unwind(AssertUnwindSafe(|| {
        let context =
            unsafe { context.as_ref() }.ok_or_else(|| "context is required".to_string())?;
        let request = parse_json::<GenerateChatRequest>(request_json, "request_json")?;
        let mut sink = CapiEventSink { callback, user_data };
        api::generate_chat_stream(context.handle.as_ref(), request, &mut sink)
            .map(|_| ())
    }));

    let result = match result {
        Ok(inner) => inner,
        Err(_) => Err("generate_chat_stream panicked".to_string()),
    };

    with_error(error_out, result).is_some()
}

#[unsafe(no_mangle)]
pub extern "C" fn inference_generate_stream(
    context: *const inference_context,
    request_json: *const c_char,
    callback: EventCallback,
    user_data: *mut c_void,
    error_out: *mut *mut c_char,
) -> bool {
    let result = catch_unwind(AssertUnwindSafe(|| {
        let context =
            unsafe { context.as_ref() }.ok_or_else(|| "context is required".to_string())?;
        let request = parse_json::<GenerateRequest>(request_json, "request_json")?;
        let mut sink = CapiEventSink { callback, user_data };
        api::generate_stream(context.handle.as_ref(), request, &mut sink).map(|_| ())
    }));

    let result = match result {
        Ok(inner) => inner,
        Err(_) => Err("generate_stream panicked".to_string()),
    };

    with_error(error_out, result).is_some()
}

#[unsafe(no_mangle)]
pub extern "C" fn inference_cancel(job_id: i64) {
    let _ = api::cancel(job_id);
}
