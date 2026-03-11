{
  "targets": [
    {
      "target_name": "addon",
      "sources": [
        "src/addon.cpp",
        "src/cuda_wrapper.cpp"
      ],
      "include_dirs": [
        "<!@(node -p \"require('node-addon-api').include\")"]
    }
  ]
}
