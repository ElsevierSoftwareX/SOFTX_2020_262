function [layers_out_cell,cell_out]=sort_per_survey_data(layers_in,varargin)

output=layers_in.list_layers_survey_data();


if isempty(varargin)
    trans_ids=findgroups(output.Voyage,output.SurveyName,output.Snapshot,output.Stratum,output.Type,output.Transect);
else
    output_table=struct2table(output);
    trans_ids=findgroups(output_table(:,varargin));
end

unique_trans=unique(trans_ids);

id_lays_out_cell=cell(1,length(unique_trans));

for i_out=1:length(id_lays_out_cell)
    id_lays_out_cell{i_out}=output.Layer_idx(trans_ids==i_out);
end

id_lays_out_cell(cellfun(@isempty,id_lays_out_cell))=[];

nb_cell_out=0;
cell_out={};

while ~isempty(id_lays_out_cell)
    nb_cell_out=nb_cell_out+1;
    idx_temp=cellfun(@(x) ~isempty(intersect(id_lays_out_cell{1},x)),id_lays_out_cell);
    cell_out{nb_cell_out}=unique([id_lays_out_cell{idx_temp}]);
    id_lays_out_cell(idx_temp)=[];
end

for icell=1:length(cell_out)
    tmp=cellfun(@(x) intersect(cell_out{icell},x),cell_out,'UniformOutput',0);
    idx_inter=find(cellfun(@(x) ~isempty(x),tmp));
    if length(idx_inter)>=2
        cell_out{icell}=unique([cell_out{idx_inter}]);
        idx = find(idx_inter~=icell);
        for ifi =idx
            cell_out{idx_inter(ifi)}=[];
        end
    end
end

cell_out(cellfun(@isempty,cell_out))=[];

layers_out_cell=cell(1,length(cell_out));

for ilay=1:length(layers_out_cell)
    layers_out_cell{ilay}=layers_in(cell_out{ilay});
end



end