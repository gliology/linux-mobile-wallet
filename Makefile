CACHIX_CACHE=linux-mobile-wallet

default:
	@echo "No default target, use 'push-inputs' and 'push-outputs' targets to upload to cachix."

push-inputs:
	nix flake archive --json \
		| jq -r '.path,(.inputs|to_entries[].value.path)' \
		| cachix push $(CACHIX_CACHE)

push-outputs:
	nix build --json \
		| jq -r '.[].outputs | to_entries[].value' \
		| cachix push $(CACHIX_CACHE)
