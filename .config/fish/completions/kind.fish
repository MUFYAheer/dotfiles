# fish completion for kind                                 -*- shell-script -*-

function __kind_debug
    set file "$BASH_COMP_DEBUG_FILE"
    if test -n "$file"
        echo "$argv" >> $file
    end
end

function __kind_perform_completion
    __kind_debug "Starting __kind_perform_completion with: $argv"

    set args (string split -- " " "$argv")
    set lastArg "$args[-1]"

    __kind_debug "args: $args"
    __kind_debug "last arg: $lastArg"

    set emptyArg ""
    if test -z "$lastArg"
        __kind_debug "Setting emptyArg"
        set emptyArg \"\"
    end
    __kind_debug "emptyArg: $emptyArg"

    set requestComp "$args[1] __complete $args[2..-1] $emptyArg"
    __kind_debug "Calling $requestComp"

    set results (eval $requestComp 2> /dev/null)
    set comps $results[1..-2]
    set directiveLine $results[-1]

    # For Fish, when completing a flag with an = (e.g., <program> -n=<TAB>)
    # completions must be prefixed with the flag
    set flagPrefix (string match -r -- '-.*=' "$lastArg")

    __kind_debug "Comps: $comps"
    __kind_debug "DirectiveLine: $directiveLine"
    __kind_debug "flagPrefix: $flagPrefix"

    for comp in $comps
        printf "%s%s\n" "$flagPrefix" "$comp"
    end

    printf "%s\n" "$directiveLine"
end

# This function does three things:
# 1- Obtain the completions and store them in the global __kind_comp_results
# 2- Set the __kind_comp_do_file_comp flag if file completion should be performed
#    and unset it otherwise
# 3- Return true if the completion results are not empty
function __kind_prepare_completions
    # Start fresh
    set --erase __kind_comp_do_file_comp
    set --erase __kind_comp_results

    # Check if the command-line is already provided.  This is useful for testing.
    if not set --query __kind_comp_commandLine
        set __kind_comp_commandLine (commandline)
    end
    __kind_debug "commandLine is: $__kind_comp_commandLine"

    set results (__kind_perform_completion "$__kind_comp_commandLine")
    set --erase __kind_comp_commandLine
    __kind_debug "Completion results: $results"

    if test -z "$results"
        __kind_debug "No completion, probably due to a failure"
        # Might as well do file completion, in case it helps
        set --global __kind_comp_do_file_comp 1
        return 0
    end

    set directive (string sub --start 2 $results[-1])
    set --global __kind_comp_results $results[1..-2]

    __kind_debug "Completions are: $__kind_comp_results"
    __kind_debug "Directive is: $directive"

    if test -z "$directive"
        set directive 0
    end

    set compErr (math (math --scale 0 $directive / 1) % 2)
    if test $compErr -eq 1
        __kind_debug "Received error directive: aborting."
        # Might as well do file completion, in case it helps
        set --global __kind_comp_do_file_comp 1
        return 0
    end

    set nospace (math (math --scale 0 $directive / 2) % 2)
    set nofiles (math (math --scale 0 $directive / 4) % 2)

    __kind_debug "nospace: $nospace, nofiles: $nofiles"

    # Important not to quote the variable for count to work
    set numComps (count $__kind_comp_results)
    __kind_debug "numComps: $numComps"

    if test $numComps -eq 1; and test $nospace -ne 0
        # To support the "nospace" directive we trick the shell
        # by outputting an extra, longer completion.
        __kind_debug "Adding second completion to perform nospace directive"
        set --append __kind_comp_results $__kind_comp_results[1].
    end

    if test $numComps -eq 0; and test $nofiles -eq 0
        __kind_debug "Requesting file completion"
        set --global __kind_comp_do_file_comp 1
    end

    # If we don't want file completion, we must return true even if there
    # are no completions found.  This is because fish will perform the last
    # completion command, even if its condition is false, if no other
    # completion command was triggered
    return (not set --query __kind_comp_do_file_comp)
end

# Remove any pre-existing completions for the program since we will be handling all of them
# TODO this cleanup is not sufficient.  Fish completions are only loaded once the user triggers
# them, so the below deletion will not work as it is run too early.  What else can we do?
complete -c kind -e

# The order in which the below two lines are defined is very important so that __kind_prepare_completions
# is called first.  It is __kind_prepare_completions that sets up the __kind_comp_do_file_comp variable.
#
# This completion will be run second as complete commands are added FILO.
# It triggers file completion choices when __kind_comp_do_file_comp is set.
complete -c kind -n 'set --query __kind_comp_do_file_comp'

# This completion will be run first as complete commands are added FILO.
# The call to __kind_prepare_completions will setup both __kind_comp_results abd __kind_comp_do_file_comp.
# It provides the program's completion choices.
complete -c kind -n '__kind_prepare_completions' -f -a '$__kind_comp_results'

