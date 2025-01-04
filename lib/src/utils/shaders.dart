import 'dart:ui';

class ShaderManager {
  // A cache to store loaded shaders
  static final Map<String, FragmentShader> _shaderCache = {};

  /// Loads and compiles a shader from the given filename.
  /// If the shader is already loaded, it is retrieved from the cache.
  static Future<FragmentShader> loadAndCompileShader(String filename) async {
    if (_shaderCache.containsKey(filename)) {
      return _shaderCache[filename]!;
    }

    // Load and compile the shader
    final FragmentProgram program = await FragmentProgram.fromAsset(
      'packages/fl_nodes/shaders/$filename',
    );
    final FragmentShader shader = program.fragmentShader();

    // Store the compiled shader in the cache
    _shaderCache[filename] = shader;

    return shader;
  }

  /// Tries to retrieve a shader from the cache.
  static FragmentShader? tryGetShader(String filename) {
    return _shaderCache[filename];
  }

  /// Clears the shader cache (if needed for debugging or resource cleanup)
  static void clearCache() {
    _shaderCache.clear();
  }
}
