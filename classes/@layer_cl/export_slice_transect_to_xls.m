function [output_2D,output_2D_type,regs,regCellInt,shadow_height_est]=export_slice_transect_to_xls(layer_obj,varargin)

[path_tmp,~,~]=fileparts(layer_obj.Filename{1});
layers_Str=list_layers(layer_obj,'nb_char',80);
output_f_def=fullfile(path_tmp,layers_Str{1});

p = inputParser;

addRequired(p,'layer_obj',@(layer_obj) isa(layer_obj,'layer_cl'));
addParameter(p,'idx_main_freq',1,@isnumeric);
addParameter(p,'idx_sec_freq',[],@isnumeric);
addParameter(p,'idx_regs',[],@isnumeric);
addParameter(p,'regs',region_cl.empty(),@(x) isa(x,'region_cl'));
addParameter(p,'timeBounds',[0 inf],@isnumeric);
addParameter(p,'survey_options',survey_options_cl,@(x) isa(x,'survey_options_cl'));
addParameter(p,'load_bar_comp',[]);

addParameter(p,'output_f',output_f_def,@ischar);

parse(p,layer_obj,varargin{:});

layer_obj.multi_freq_slice_transect2D(...  
    'idx_main_freq',p.Results.idx_main_freq,...
    'idx_sec_freq',p.Results.idx_sec_freq,...
    'idx_regs',p.Results.idx_regs,...
    'regs',p.Results.regs,...
    'timeBounds',p.Results.timeBounds,...
    'survey_options',p.Results.survey_options,...
    'load_bar_comp',p.Results.load_bar_comp);

            
output_2D=layer_obj.EchoIntStruct.output_2D;
output_2D_type=layer_obj.EchoIntStruct.output_2D_type;
regs_tot=layer_obj.EchoIntStruct.regs_tot;
regCellInt_tot=layer_obj.EchoIntStruct.regCellInt_tot;
reg_descr_table=layer_obj.EchoIntStruct.reg_descr_table;
shadow_height_est=layer_obj.EchoIntStruct.shz_height_est;
idx_freq_out=layer_obj.EchoIntStruct.idx_freq_out;

idx_main=p.Results.idx_main_freq==idx_freq_out;
regCellInt=regCellInt_tot{idx_main};
regs=regs_tot{idx_main};

if p.Results.RegInt
    output_f=[p.Results.output_f '_regions_descr.csv'];
    if exist(output_f,'file')>1
        delete(output_f);
    end
    writetable(reg_descr_table,output_f);
end


for ir=1:numel(output_2D_type{idx_main})
    if ~isempty(output_2D{idx_main}{ir})
        fname=generate_valid_filename([p.Results.output_f '_' output_2D_type{idx_main}{ir} '_' num2str(layer_obj.Frequencies(p.Results.idx_main_freq)) '_sliced_transect.csv']);
        reg_output_table=reg_output_to_table(output_2D{idx_main}{ir});
        writetable(reg_output_table,fname);
    end
end


end

