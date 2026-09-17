{{flutter_js}}
{{flutter_build_config}}

(async () => {
  try {
    await import('./pdf-loader.mjs');
    await _flutter.loader.load();
  } catch (error) {
    console.error('Falha ao iniciar ANDERFIT', error);
    document.getElementById('startup-error').hidden = false;
  }
})();
