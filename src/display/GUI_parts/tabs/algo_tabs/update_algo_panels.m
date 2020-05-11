
function update_algo_panels(main_figure,names)

layer=get_current_layer();
curr_disp=get_esp3_prop('curr_disp');
algo_panels=getappdata(main_figure,'Algo_panels');
if isempty(algo_panels)
    return;
end

algo_panels(~isvalid(algo_panels))=[];

[trans_obj,~]=layer.get_trans(curr_disp);

for ui = 1:numel(algo_panels)
    if isempty(names)||ismember(algo_panels(ui).algo.Name,names)
        [idx_algo,found]=find_algo_idx(trans_obj,algo_panels(ui).algo.Name);
        if found==0
            idx_algo=find(strcmpi({layer.Algo(:).Name},algo_panels(ui).algo.Name));
            if ~isempty(idx_algo)
                algo_obj=layer.Algo(idx_algo);
                algo_panels(ui).update_algo_panel(algo_obj);
                algo_panels(ui).reset_default_params_h();
            end
        else
            algo_obj=trans_obj.Algo(idx_algo);
            algo_panels(ui).update_algo_panel(algo_obj);
            algo_panels(ui).reset_default_params_h();
        end
    end
end


end
