function is_char_cell_empty(x)
bool =  ischar(x)||iscell(x)||isempty(x);

if ~bool
    error('validation_fcn:is_char_cell_empty','Error in validation function. \nInput must be a cell array, a char or empty, not a %s.',class(x))
end