{
  self.overlays.overlays.models = {
    flake = true;
    deps = [ "huggingface" ];
    value = final: prev: {
      qwen-3-5-800M = final.harasPackages.fetchhf {
        name = "qwen-3-5-800M";
        repo = "Qwen/Qwen3.5-0.8B";
        hash = "sha256-9cGbWrK6hwlGSqtSlObzxwGiAJnGb+GcG0BEgb2XHeo=";
      };

      occamy = final.harasPackages.fetchhf {
        name = "occamy";
        repo = "Accio-Lab/occamy-1.0-FP8";
        hash = "sha256-+ddifnpcs3+NS2xk/csxZHMJG3wk6AZMcdVH6qYCttc=";
      };

      gemma-4-e4b = final.harasPackages.fetchhf {
        name = "gemma-4-e4b";
        repo = "google/gemma-4-E4B-it";
        hash = "sha256-f1c1UZH6wlzzixI/GpYp55Pi2ag4uxV2SgvhzGQugSg=";
      };

      qwen-3-embedding = final.harasPackages.fetchhf {
        name = "qwen-3-embedding";
        repo = "Qwen/Qwen3-Embedding-0.6B";
        hash = "sha256-6kml2X+Ha0Qg3jUP/AHiflfOtNxd1Q2ca3LzdNghvpA=";
      };

      qwen-3-8-flash-next-iq2-xs = final.harasPackages.fetchgguf {
        name = "qwen-3-8-flash-next-iq2-xs";
        repo = "ISTA-DASLab/Qwen3.8-Flash-Next-GSQ-RCO-GGUF";
        rev = "ed59f92082b1e93c0e96d60a8b11aab089b52f09";
        include = [
          "IQ2_XS/*"
          "mmproj-Qwen3.8-Flash-Next-BF16.gguf"
        ];
        hash = "sha256-9P2TykkSZy6ByF+ZbfsS57xo+DNcua1ftgAG20j3zYM=";
        passthru = {
          quant = "IQ2_XS";
          shard1 = "IQ2_XS/Qwen3.8-Flash-Next-GSQ-RCO-IQ2_XS-00001-of-00002.gguf";
          pleShard = "IQ2_XS/Qwen3.8-Flash-Next-GSQ-RCO-IQ2_XS-00002-of-00002.gguf";
          mmproj = "mmproj-Qwen3.8-Flash-Next-BF16.gguf";
          modelName = "qwen3.8-flash-next";
        };
      };
    };
  };
}
