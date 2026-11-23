function fish_command_not_found
    if command -q command-not-found
        command-not-found $argv
    else
        echo "fish: Unknown command: $argv[1]" >&2
    end
end
