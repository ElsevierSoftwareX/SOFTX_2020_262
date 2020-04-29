%% get_str_for_eval.m
%
% TODO: write short description of function
%
%% Help
%
% *USE*
%
% create input and output variable names for use in apply_algo based on the
% algo -bject
%
% *INPUT VARIABLES*
%
% * |algo_obj|: algo_cl() objects
%
% *OUTPUT VARIABLES*
%
% * |str_eval|: string for use in apply_algo in feval
% * |str_output|: string for use in apply_algo as output
%
% *RESEARCH NOTES*
%
% TODO: write research notes
%
% *NEW FEATURES*
%
% * 2017-09-04: first version (Yoann Ladroit).
%
% *EXAMPLE*
%
% TODO: write examples
%
% *AUTHOR, AFFILIATION & COPYRIGHT*
%
% Yoann Ladroit, NIWA. Type |help EchoAnalysis.m| for copyright information.

%% Function

function [str_eval,str_output]=get_str_for_eval(algo_obj)

str_eval=[];
varin=algo_obj.init_input_params();
fields_algo_in=fields(varin);

for i=1:length(fields_algo_in)
    
    if ischar(varin.(fields_algo_in{i}))
        str_eval=[str_eval sprintf('''%s'',',fields_algo_in{i})];
        str_eval=[str_eval sprintf('''%s'',',varin.(fields_algo_in{i}))];
    elseif isnumeric(varin.(fields_algo_in{i}))||islogical(varin.(fields_algo_in{i}))
        str_eval=[str_eval sprintf('''%s'',',fields_algo_in{i})];
        str_eval=[str_eval '['];
        str_eval=[str_eval sprintf('%f ',varin.(fields_algo_in{i}))];
        str_eval=[str_eval '],'];
    end
end

str_eval(end)=[];

str_output=[];
fields_algo_out=algo_obj.Varargout;

for i=1:length(fields_algo_out)
    str_output=[str_output sprintf('%s ',fields_algo_out{i})];
end
if ~isempty(str_output)
    str_output(end)=[];
end

