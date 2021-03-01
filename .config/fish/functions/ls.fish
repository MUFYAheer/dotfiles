#
# Make ls use lsd.
#

function ls --description "List contents of directory" -V opt
    command lsd $argv
end
