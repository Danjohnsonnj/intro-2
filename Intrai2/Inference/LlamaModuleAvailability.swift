/// Slice 0 wiring check — real inference arrives in Slice 1.
enum LlamaModuleAvailability {
    static var isLinked: Bool {
        #if canImport(llama)
        true
        #else
        false
        #endif
    }
}
