function tag=apply_classification_tree(tree_obj,school_struct)

fields=fieldnames(school_struct);

missing_variables=setdiff(tree_obj.Variables,fields);
if ~isempty(missing_variables)
    
    warndlg_perso([],'Cannot Classify','All Variables not defined, cannot classify');
    fprintf('\nAvailable variables:\n');
    fprintf(' %s\n',fields{:});
    
    fprintf('\nRequired variables:\n');
    fprintf(' %s\n',tree_obj.Variables{:});
    
    fprintf('\nMissing variables:\n');
    fprintf('% s\n',missing_variables{:});
    
    
    return;
end

switch lower(tree_obj.ClassificationType)
    case 'cell by cell'
        idx_to_classify=find(school_struct.eint>0);
        tag=strings(size(school_struct.eint));
        [idx_to_classify_j,idx_to_classify_i]=find(school_struct.eint>0);
    case 'by regions'
        idx_to_classify=find(~isnan(school_struct.(tree_obj.Variables{1})));
        [idx_to_classify_j,idx_to_classify_i]=find(~isnan(school_struct.(tree_obj.Variables{1})));
        tag=strings(size(school_struct.(tree_obj.Variables{1})));
end



classified=false(size(school_struct.(tree_obj.Variables{1})));

for ui=1:numel(idx_to_classify)
    for ifi=1:numel(tree_obj.Variables)
        if numel(school_struct.(tree_obj.Variables{ifi}))==1
            school.(tree_obj.Variables{ifi})=school_struct.(tree_obj.Variables{ifi});
        elseif isrow(school_struct.(tree_obj.Variables{ifi}))
            school.(tree_obj.Variables{ifi})=school_struct.(tree_obj.Variables{ifi})(idx_to_classify_i(ui));
        elseif iscolumn(school_struct.(tree_obj.Variables{ifi}))
            school.(tree_obj.Variables{ifi})=school_struct.(tree_obj.Variables{ifi})(idx_to_classify_j(ui));
        else
            school.(tree_obj.Variables{ifi})=school_struct.(tree_obj.Variables{ifi})(idx_to_classify(ui));
        end
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
                output=eval(node.Condition);
            catch
                warning('Failed on evaluation of condition %s...',node.Condition);
                continue;
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
            warning('Cannot use this tree...');
            continue;
        end
    end
    
end

