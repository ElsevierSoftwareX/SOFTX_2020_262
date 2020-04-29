function apply_cw_cal(trans_obj,new_cal)

old_cal=trans_obj.get_cal();

if isnan(new_cal.G0)
    new_cal.G0=old_cal.G0;
end
if isnan(new_cal.SACORRECT)
    new_cal.SACORRECT=old_cal.SACORRECT;
end

if isnan(new_cal.EQA)
    new_cal.EQA=old_cal.EQA;
end

if round(old_cal.G0*100)==round(new_cal.G0*100)&&round(old_cal.SACORRECT*100)==round(new_cal.SACORRECT*100)&&round(old_cal.EQA*100)==round(new_cal.EQA*100)
    return;
end

if isnan(new_cal.G0)
    new_cal.G0=old_cal.G0;
end

trans_obj.set_cal(struct('G0',new_cal.G0,'SACORRECT',new_cal.SACORRECT,'EQA',new_cal.EQA));
fprintf('Applying Calibration\n');
trans_obj.disp_calibration_env_params([]);

switch trans_obj.Mode
    case 'CW'
        diff_db_sv=2*(old_cal.SACORRECT-new_cal.SACORRECT)+2*(old_cal.G0-new_cal.G0)+2*(old_cal.EQA-new_cal.EQA);
        trans_obj.Data.add_to_sub_data('sv',diff_db_sv);
        diff_db_sp=2*(old_cal.G0-new_cal.G0);
        trans_obj.Data.add_to_sub_data('sp',diff_db_sp);
    case 'FM'
        
        diff_db_sv=+2*(old_cal.G0-new_cal.G0)+2*(old_cal.EQA-new_cal.EQA);
        trans_obj.Data.add_to_sub_data('sv',diff_db_sv);
        trans_obj.Data.add_to_sub_data('svunmatched',diff_db_sv);
        diff_db_sp=2*(old_cal.G0-new_cal.G0);
        trans_obj.Data.add_to_sub_data('sp',diff_db_sp);
        trans_obj.Data.add_to_sub_data('spunmatched',diff_db_sp);
end


end

