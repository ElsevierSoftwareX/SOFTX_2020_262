function tag=apply_classification_tree(tree_obj,var_struct,load_bar_comp)

fields=fieldnames(var_struct);

missing_variables=setdiff(tree_obj.Variables,fields);
if ~isempty(missing_variables)
    
    warndlg_perso([],'Cannot Classify','All Variables not defined, cannot classify');
    fprintf('\nAvailable variables:\n');
    fprintf(' %s\n',fields{:});
    
    fprintf('\nRequired variables:\n');
    fprintf(' %s\n',tree_obj.Variables{:});
    
    fprintf('\nMissing variables:\n');
    fprintf('% s\n',missing_variables{:});
    
    tag = '';
    return;
end

switch lower(tree_obj.ClassificationType)
    case 'cell by cell'
        idx_to_classify=find(var_struct.eint>0);
        tag=strings(size(var_struct.eint));
        [idx_to_classify_j,idx_to_classify_i]=find(var_struct.eint>0);
    case 'by regions'
        idx_to_classify=find(~isnan(var_struct.(tree_obj.Variables{1})));
        [idx_to_classify_j,idx_to_classify_i]=find(~isnan(var_struct.(tree_obj.Variables{1})));
        tag=strings(size(var_struct.(tree_obj.Variables{1})));
end

for ifi=1:numel(tree_obj.Variables)
    if numel(var_struct.(tree_obj.Variables{ifi}))==1
        var_tot_struct.(tree_obj.Variables{ifi})=var_struct.(tree_obj.Variables{ifi})*ones(size(tag));
    elseif isrow(var_struct.(tree_obj.Variables{ifi}))
        var_tot_struct.(tree_obj.Variables{ifi})=var_struct.(tree_obj.Variables{ifi})(idx_to_classify_i);
    elseif iscolumn(var_struct.(tree_obj.Variables{ifi}))
        var_tot_struct.(tree_obj.Variables{ifi})=var_struct.(tree_obj.Variables{ifi})(idx_to_classify_j);
    else
        var_tot_struct.(tree_obj.Variables{ifi})=var_struct.(tree_obj.Variables{ifi})(idx_to_classify);
    end
end

classified=false(size(var_struct.(tree_obj.Variables{1})));

if ~isempty(load_bar_comp)
    set(load_bar_comp.progress_bar, 'Value',0,'Minimum',0,'Maximum',numel(idx_to_classify));
end

for ui=1:numel(idx_to_classify)
    if ~isempty(load_bar_comp)&&rem(ui,100)==0
        set(load_bar_comp.progress_bar, 'Value',ui+1);
    end
    for ifi=1:numel(tree_obj.Variables)
        struct_to_eval.(tree_obj.Variables{ifi})=var_tot_struct.(tree_obj.Variables{ifi})(ui);
    end
    
    IDs_cond=tree_obj.get_condition_node();
    IDs_class=tree_obj.get_class_node();
    if ~isempty(IDs_cond)
        ID_goto=nanmin(IDs_cond);
    end
    
    while ~classified((idx_to_classify(ui)))
        node=tree_obj.get_node(ID_goto);
        if any(ID_goto==IDs_cond)
            try
                output=eval(strrep(node.Condition,tree_obj.VarName,'struct_to_eval'));
            catch
                print_errors_and_warnings([],'warning',sprintf('Failed on evaluation of condition %s...',node.Condition));
                return;
            end
            if output>=1
                ID_goto=node.true_target;
            else
                ID_goto=node.false_target;
            end
        elseif any(ID_goto==IDs_class)
            tag((idx_to_classify(ui)))=node.Class;
            classified((idx_to_classify(ui)))=true;
        else
            print_errors_and_warnings([],'warning',sprintf('Problem with the classification tree %s...',tree_obj.Title));
            return;
        end
    end
    
end

