function [snaps,types,strat,trans,regs,cells]=merge_survey_input_for_integration(surv_in_obj,varargin)

p = inputParser;
addRequired(p,'surv_in_obj',@(obj) isa(obj,'survey_input_cl'));
parse(p,surv_in_obj,varargin{:});

[snap_vec,type_vec,strat_vec,trans_vec,~,~,regs_cell,cells_cell]=list_transects(surv_in_obj);

[idx_g,snaps,types,strat,trans]=findgroups(snap_vec,type_vec,strat_vec,trans_vec);

regs=cell(1,length(snaps));
cells=cell(1,length(snaps));


for i=1:length(trans)
    cells_temp=[cells_cell{i==idx_g}];

    idx_tag=find(cellfun(@(x) isfield(x,'tag'),cells_temp));
    cells_temp_struct=[cells_temp{idx_tag}];
    
    if ~isempty(idx_tag)
        cell_tags={cells_temp_struct(:).tag};
        tag_cell= cellfun(@(x) strsplit(x,';'),cell_tags,'un',0);
        tag_cell_out={};
        for icell=1:numel(tag_cell)
        tag_cell_out=union(tag_cell_out,tag_cell{icell});
        end
        cells{i}=tag_cell_out;
    end
    
    
    reg_temp=[regs_cell{i==idx_g}];
    idx_keep=[];
    idx_ID=find(cellfun(@(x) isfield(x,'IDs'),reg_temp));
    reg_temp_struct=[reg_temp{idx_ID}];
    
    if ~isempty(reg_temp_struct)
        if ischar(reg_temp_struct(1).IDs)
            [~,idx_tmp]=unique({reg_temp_struct.IDs});
        else
            [~,idx_tmp]=unique(reg_temp_struct.IDs);
        end
        idx_keep=union(idx_keep,idx_ID(idx_tmp));
    end
    
    idx_name=find(cellfun(@(x) isfield(x,'name'),reg_temp));
    reg_temp_struct=[reg_temp{idx_name}];
    
    if ~isempty(reg_temp_struct)
        [~,idx_tmp]=unique({reg_temp_struct.name});
        idx_keep=union(idx_keep,idx_name(idx_tmp));
    end
    
        idx_tag=find(cellfun(@(x) isfield(x,'tag'),reg_temp));
    reg_temp_struct=[reg_temp{idx_tag}];
    
    if ~isempty(reg_temp_struct)        
        if ischar(reg_temp_struct(1).tag)
            [~,idx_tmp]=unique({reg_temp_struct.tag});
        else
            [~,idx_tmp]=unique(reg_temp_struct.tag);
        end
        idx_keep=union(idx_keep,idx_tag(idx_tmp));
    end
    
    if ~isempty(idx_keep)
        regs{i}=reg_temp(idx_keep);
    end
    
    
end

types(cellfun(@isempty,types))={' '};
strat(cellfun(@isempty,strat))={' '};


end