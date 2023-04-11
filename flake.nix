{
  outputs = { ... }: {
    templates.rust = {
      path = ./rust-env;
      description = "rust development environment";
    };

    templates.rust-gl = {
      path = ./rust-gl-env;
      description = "rust development environment with OpenGL/Vulkan support";
    };
  };
}
