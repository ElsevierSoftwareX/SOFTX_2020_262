%% apply_algo.m
%
% TODO: write short description of function
%
%% Help
%
% *USE*
%
% TODO: write longer description of function
%
% *INPUT VARIABLES*
%
% * |trans_obj|: TODO: write description and info on variable
% * |algo_name|: TODO: write description and info on variable
%
% *OUTPUT VARIABLES*
%
% * |output_struct|: TODO: write description and info on variable
%
% *RESEARCH NOTES*
%
% TODO: write research notes
%
% *NEW FEATURES*
%
% * 2017-03-28: header (Alex Schimel)
% * YYYY-MM-DD: first version (Yoann Ladroit)
%
% *EXAMPLE*
%
% TODO: write examples
%
% *AUTHOR, AFFILIATION & COPYRIGHT*
%
% Yoann Ladroit, NIWA. Type |help EchoAnalysis.m| for copyright information.

%% Function
function output_struct= apply_algo(trans_obj,algo_name,varargin)


p = inputParser;

addRequired(p,'trans_obj',@(obj) isa(obj,'transceiver_cl'));
addRequired(p,'algo_name',@(x) ismember(x,list_algos()));
addParameter(p,'replace_bot',1,@isnumeric);
addParameter(p,'reg_obj',region_cl.empty(),@(x) isa(x,'region_cl')||ischar(x)||isnumeric(x));
addParameter(p,'block_len',[],@(x) x>0 ||isempty(x));
addParameter(p,'load_bar_comp',[]);
addParameter(p,'force_ignore_status_bar',0,@isnumeric);

parse(p,trans_obj,algo_name,varargin{:});

if isempty(p.Results.block_len)
    block_len=get_block_len(100,'cpu');
else
    block_len= p.Results.block_len;
end

fig=[];
init_state=0;

if p.Results.force_ignore_status_bar==0
    fig=findobj(0,'Type','figure','-and','Name','ESP3');
    if ~isempty(fig)
        [~,init_state]=show_status_bar(fig,0);
    end
end
output_struct.done = false;
try
    
    [idx_alg,alg_found]=find_algo_idx(trans_obj,algo_name);
    
    switch class(p.Results.reg_obj)
        case 'region_cl'
            reg_obj=p.Results.reg_obj;
        case 'char'
            idx=trans_obj.find_regions_tag(p.Results.reg_obj);
            if isempty(idx)
                reg_obj=region_cl.empty();
            else
                reg_obj=trans_obj.Regions(idx);
            end
        otherwise
            if isnumeric(p.Results.reg_obj)
                idx=trans_obj.find_regions_ID(p.Results.reg_obj);
                if isempty(idx)
                    reg_obj=region_cl.empty();
                else
                    reg_obj=trans_obj.Regions(idx);
                end
            else
                reg_obj=region_cl.empty();
            end
    end
    
    if alg_found==0
        algo_obj=init_algos(algo_name);
        trans_obj.add_algo(algo_obj);
    else
        algo_obj=trans_obj.Algo(idx_alg);
    end
    
    if isempty(algo_obj)
        return;
    end

    if ~isempty(p.Results.load_bar_comp)
        p.Results.load_bar_comp.progress_bar.setText(sprintf('Applying %s on %.0f kHz',algo_name,trans_obj.Config.Frequency/1e3));
    end
    
    varin=namedargs2cell(algo_obj.input_params_to_struct());
    
    output_struct=feval(algo_obj.Function,trans_obj,'load_bar_comp',p.Results.load_bar_comp,'block_len',block_len,varin{:},'reg_obj',reg_obj);

    if ~isempty(p.Results.load_bar_comp)
        p.Results.load_bar_comp.progress_bar.setText('');
        set(p.Results.load_bar_comp.progress_bar, 'Minimum',0, 'Maximum',100, 'Value',0);
    end
    

catch err
    print_errors_and_warnings(1,'error',err);
end

if ~init_state
    hide_status_bar(fig);
end

end

