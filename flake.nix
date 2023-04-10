{
  outputs = { ... }: {
    templates.rust = {
      path = ./rust-env;
      description = "rust development environment";
    };
  };
}
