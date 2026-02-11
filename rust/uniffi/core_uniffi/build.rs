fn main() {
    uniffi::generate_scaffolding("src/ente_core.udl").expect("generate uniffi scaffolding");
}
