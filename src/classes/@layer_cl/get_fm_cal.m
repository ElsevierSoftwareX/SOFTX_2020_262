function [cal_fm_cell,used]=get_fm_cal(layer_obj,idx_trans)

[cal_path,~,~]=fileparts(layer_obj.Filename{1});

if isempty(idx_trans)
    idx_trans=1:numel(layer_obj.Frequencies);
end
cal_fm_cell=cell(1,numel(idx_trans));
used=cell(1,numel(idx_trans));


for uui=1:numel(idx_trans)
    
    try
        switch layer_obj.Transceivers(idx_trans(uui)).Mode
            case 'FM'
                trans_obj=layer_obj.Transceivers(idx_trans(uui));
                
                [cal_fm_cell{uui},used{uui}]=trans_obj.get_fm_cal(cal_path);
        end
        
    catch err
        print_errors_and_warnings([],'error',err);       
    end
end
