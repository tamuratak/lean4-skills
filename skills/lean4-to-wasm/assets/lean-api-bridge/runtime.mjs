export async function createLeanWasm(loaderUrl) {
  const { default: createModule } = await import(/* @vite-ignore */ loaderUrl.href);
  const module = await createModule();
  if (module._lean_wasm_init()) throw new Error("Lean Wasm initialization failed");
  return {
    call(source) {
      if (source.includes("\0")) throw new Error("Lean Wasm connection error: raw NUL in source");
      const text = source.toWellFormed();
      const size = module.lengthBytesUTF8(text) + 1;
      const pointer = module._malloc(size);
      if (!pointer) throw new Error("Lean Wasm input allocation failed");
      let result = 0;
      try {
        module.stringToUTF8(text, pointer, size);
        result = module._lean_wasm_call(pointer);
        if (!result) throw new Error("Lean Wasm execution failed");
        return module.UTF8ToString(result);
      } finally {
        if (result) module._free(result);
        module._free(pointer);
      }
    },
  };
}
