
function search_callback(~,~,surv_tab)
surv_data_table=getappdata(surv_tab,'surv_data_table');

data_ori=getappdata(surv_tab,'data_ori');
%text_search=regexprep(get(surv_data_table.search_box,'string'),'[^\w'']','');



file=get(surv_data_table.file,'value');
snap=get(surv_data_table.snap,'value');
type=get(surv_data_table.type,'value');
strat=get(surv_data_table.strat,'value');
trans=get(surv_data_table.trans,'value');
reg=get(surv_data_table.reg,'value');
text_search_tot=strtrim(get(surv_data_table.search_box,'string'));
if isempty(text_search_tot)||(~file&&~snap&&~trans&&~strat&&~reg&&~type)
    data=data_ori;
else
    text_search_tot=strsplit(get(surv_data_table.search_box,'string'),' ');
    
    idx_tot=true(size(data_ori,1),1);
    
    for i=1:numel(text_search_tot)
        text_search=strtrim(text_search_tot{i});
        if isempty(text_search)
            continue;
        end
        
        if snap>0
            idx_snap=cellfun(@double,data_ori(:,3))==str2double(text_search);
            %idx_snap=contains(cellfun(@num2str,data_ori(:,3),'un',0),text_search,'IgnoreCase',true);
        else
            idx_snap=zeros(size(data_ori,1),1);
        end
        
        if type>0
            idx_type=contains(data_ori(:,4),text_search,'IgnoreCase',true);
        else
            idx_type=zeros(size(data_ori,1),1);
        end
        
        
        if trans>0
            idx_trans=cellfun(@double,data_ori(:,6))==str2double(text_search);
        else
            idx_trans=zeros(size(data_ori,1),1);
        end
        
        if strat>0
            idx_strat=contains(data_ori(:,5),text_search,'IgnoreCase',true);
        else
            idx_strat=zeros(size(data_ori,1),1);
        end
        
        if file>0
            %         files=regexprep(data_ori(:,2),'[^\w'']','');
            %         out_files=regexpi(files,text_search);
            %         idx_files=cellfun(@(x) ~isempty(x),out_files);
            idx_files=contains(data_ori(:,2),text_search,'IgnoreCase',true);
        else
            idx_files=zeros(size(data_ori,1),1);
        end
        
        if reg>0
            %         regs=regexprep(data_ori(:,8),'[^\w'']','');
            %         out_regs=regexpi(regs,text_search);
            %         idx_regs=cellfun(@(x) ~isempty(x),out_regs);
            idx_regs=contains(data_ori(:,8),text_search,'IgnoreCase',true);
        else
            idx_regs=zeros(size(data_ori,1),1);
        end
        
        idx_tot=idx_tot&(idx_snap|idx_type|idx_strat|idx_files|idx_trans|idx_regs);
    end
    data=data_ori(idx_tot,:);
end


set(surv_data_table.table_main,'Data',data);

end