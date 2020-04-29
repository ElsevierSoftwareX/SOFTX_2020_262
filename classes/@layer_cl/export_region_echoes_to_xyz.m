function export_region_echoes_to_xyz(layer_obj,active_reg,varargin)

[path_tmp,~,~]=fileparts(layer_obj.Filename{1});
layers_Str=list_layers(layer_obj,'nb_char',80);
output_f_def=fullfile(path_tmp,[layers_Str{1} '_regions' '.xlsx']);

p = inputParser;
addRequired(p,'layer_obj',@(x) isa(x,'layer_cl'));
addRequired(p,'active_reg',@(x) isa(x,'region_cl'));
addParameter(p,'output_f',output_f_def,@ischar);
addParameter(p,'field','TS',@ischar);
addParameter(p,'thr',-50,@isnumeric);
addParameter(p,'idx_freq',1,@isnumeric);
addParameter(p,'idx_freq_end',[],@isnumeric),...
addParameter(p,'cmap','ek60',@ischar);

parse(p,layer_obj,active_reg,varargin{:});

field=p.Results.field;


if isnan(p.Results.thr)
    switch field
        case {'sp','TS'}
            thr=-65;
        case'sv'
            thr=-75;
        otherwise
            thr=-Inf;
    end
else
    thr=p.Results.thr;
end


for u=1:numel(active_reg)
    
    [regs_end,idx_freq_end,~,~]=layer_obj.generate_regions_for_other_freqs(p.Results.idx_freq,active_reg(u),p.Results.idx_freq_end);
    regs=[active_reg(u) regs_end];
    [idx_freq_sort,is]=sort([p.Results.idx_freq,idx_freq_end]);
    regs=regs(is);
    
    for ir=1:length(idx_freq_sort)
        [data_struct_new,~,~] = regs(ir).get_region_3D_echoes(layer_obj.Transceivers(idx_freq_sort(ir)),'field',field,'thr',thr);
        if u==1
            data_tot.(sprintf('data%d',ir))=data_struct_new;
        else
            fields=fieldnames(data_struct_new);
            for ifi=1:numel(fields)
                data_tot.(sprintf('data%d',ir)).(fields{ifi})= [data_tot.(sprintf('data%d',ir)).(fields{ifi});data_struct_new.(fields{ifi})];
            end
        end
    end
    
    
end

[path_out_f,file_base,ext]=fileparts(p.Results.output_f);
switch ext    
    case '.xyz'
        for ifif=1:length(idx_freq_sort)
            file_tmp=fullfile(path_out_f,[file_base '_' strrep(layer_obj.Transceivers(ifif).Config.TransceiverName,'  ','') sprintf('_%.0fkHz_%s',layer_obj.Frequencies(idx_freq_sort(ifif))/1e3,field) ext]);
            fid=fopen(file_tmp,'w+');
            fprintf(fid,'lon lat depth %s\n',field);
            idx_keep=find(data_tot.(sprintf('data%d',ifif)).data_disp>thr);
            for i=1:numel(idx_keep)
                switch field
                    case 'TS'
                           data_exp= data_tot.(sprintf('data%d',ifif)).data_disp(idx_keep(i))+data_tot.(sprintf('data%d',ifif)).compensation(idx_keep(i));
                    otherwise
                          data_exp= data_tot.(sprintf('data%d',ifif)).data_disp(idx_keep(i));
                end
                                fprintf(fid,'%.6f %.6f %.2f %.2f\n',...
                    data_tot.(sprintf('data%d',ifif)).lon(idx_keep(i)),...
                    data_tot.(sprintf('data%d',ifif)).lat(idx_keep(i)),...
                    data_tot.(sprintf('data%d',ifif)).depth(idx_keep(i)),...
                    data_exp);
            end

            fclose(fid);
        end
        
    case '.vrml'
        for ifif=1:length(idx_freq_sort)
            file_tmp=fullfile(path_out_f,[file_base '_' strrep(layer_obj.Transceivers(idx_freq_sort(ifif)).Config.TransceiverName,'  ','') sprintf('_%.0fkHz_%s',layer_obj.Frequencies(idx_freq_sort(ifif))/1e3,field) ext]);
            idx_keep=find(data_tot.(sprintf('data%d',ifif)).data_disp>p.Results.thr);
            [X,Y]=ll2utm(data_tot.(sprintf('data%d',ifif)).lat(idx_keep),data_tot.(sprintf('data%d',ifif)).lon(idx_keep));
            writeVrmlPoint_chs(...
                X,...
                Y,...
                data_tot.(sprintf('data%d',ifif)).depth(idx_keep),...
                data_tot.(sprintf('data%d',ifif)).data_disp(idx_keep),...
                'filename',file_tmp,...
                'thr_min',p.Results.thr,...
                'thr_max',nanmax(data_tot.(sprintf('data%d',ifif)).data_disp(idx_keep)),'cmap',p.Results.cmap);
        end
end
disp('Done');

end