use anyhow::Error;
use std::vec::Vec;
use zsh_module::{Builtin, MaybeError, Module, ModuleBuilder, Opts};

mod fakemain;

zsh_module::export_module!(starship_mod, setup);

struct StarshipZMod;

impl StarshipZMod {
    fn new() -> StarshipZMod {
        fakemain::init();
        StarshipZMod
    }

    fn cmd(&mut self, _name: &str, raw_args: &[&str], _opts: Opts) -> MaybeError {
        let mut args: Vec<&str> = Vec::new();
        args.push("starship");
        args.extend_from_slice(raw_args);

        fakemain::fakemain(&args);
        Ok(())
    }
}

fn setup() -> Result<Module, Error> {
    let module = ModuleBuilder::new(StarshipZMod::new())
        .builtin(StarshipZMod::cmd, Builtin::new("starship"))
        .build();
    Ok(module)
}
