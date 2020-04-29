function output_struct_cell= apply_algo(layer_obj,algo_name,varargin)

p = inputParser;

addRequired(p,'layer_obj',@(obj) isa(obj,'layer_cl'));
addRequired(p,'algo_name',@(x) ismember(x,list_algos()));
addParameter(p,'idx_chan',1:numel(layer_obj.ChannelID),@isnumeric);
addParameter(p,'timeBounds',[0 inf],@isnumeric);
addParameter(p,'survey_options',layer_obj.get_survey_options(),@(x) isa(x,'survey_options_cl'));
addParameter(p,'replace_bot',1,@isnumeric);
addParameter(p,'reg_obj',region_cl.empty(),@(x) isa(x,'region_cl')||ischar(x)||isnumeric(x));
addParameter(p,'block_len',get_block_len(50,'cpu'),@(x) x>0);
addParameter(p,'load_bar_comp',[]);
addParameter(p,'force_ignore_status_bar',0,@isnumeric);

parse(p,layer_obj,algo_name,varargin{:});
output_struct_cell={};

if isempty(p.Results.block_len)
    block_len=get_block_len(100,'cpu');
else
    block_len= p.Results.block_len;
end

switch algo_name
    case 'Classification'
        
        idx_al=find(strcmpi(algo_name,{layer_obj.Algo(:).Name}),1);
        if ~isempty(idx_al)    
            
            if ~isempty(p.Results.load_bar_comp)
                p.Results.load_bar_comp.progress_bar.setText(sprintf('Applying %s',algo_name));
            end
            algo_obj=layer_obj.Algo(idx_al);
            
            varin=namedargs2cell(algo_obj.input_params_to_struct());
            
            output_struct_tmp=feval(algo_obj.Function,layer_obj,...
                'load_bar_comp', p.Results.load_bar_comp,...
                'survey_options',p.Results.survey_options,...
                'timeBounds',p.Results.timeBounds,...
                varin{:},...
                'reg_obj',p.Results.reg_obj);
            
            if ~isempty(p.Results.load_bar_comp)
                p.Results.load_bar_comp.progress_bar.setText('');
                set(p.Results.load_bar_comp.progress_bar, 'Minimum',0, 'Maximum',100, 'Value',0);
            end
            
            output_struct_cell={output_struct_tmp};
        end
    otherwise
        idx_chan=p.Results.idx_chan;
        
        idx_chan(idx_chan>numel(layer_obj.ChannelID))=[];
        
        output_struct_cell=cell(1,numel(idx_chan));
        
        for ui = 1 : numel(idx_chan)
            output_struct_cell{ui}=layer_obj.Transceivers(idx_chan(ui)).apply_algo(algo_name,...
                'replace_bot',p.Results.replace_bot,...
                'block_len',block_len,...
                'reg_obj',p.Results.reg_obj,...
                'force_ignore_status_bar',p.Results.force_ignore_status_bar,...
                'load_bar_comp',p.Results.load_bar_comp);
        end
        
end
