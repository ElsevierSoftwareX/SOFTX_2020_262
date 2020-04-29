
function cal=get_cal(trans_obj)

    G0=trans_obj.get_current_gain();
    SACORRECT=trans_obj.get_current_sacorr();
    EQA=trans_obj.Config.EquivalentBeamAngle;
    alpha=nanmean(trans_obj.get_absorption())*1e3;
    cal=struct('G0',G0,'SACORRECT',SACORRECT,'EQA',EQA,'alpha',alpha);   

end