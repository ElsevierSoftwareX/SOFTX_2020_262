function cal_merged=merge_calibration(cal_init,cal_master)

cal_merged=cal_init;
fields=fieldnames(cal_init);

if ~isempty(cal_master)
    for ical=1:numel(cal_init.G0)
        if isfield(cal_init,'CID')
            idx_cal=find(strcmp(cal_init.CID{ical},cal_master.CID),1);
        end
        
        if isempty(idx_cal)
            idx_cal=find(cal_init.FREQ(ical)==cal_master.FREQ,1);
        end
        
        if ~isempty(idx_cal)
            for ifi=1:numel(fields)
                if isnumeric(cal_master.(fields{ifi}))
                    if ~isnan(cal_master.(fields{ifi})(idx_cal))
                        cal_merged.(fields{ifi})(ical)= cal_master.(fields{ifi})(idx_cal);
                    end
                else
                    if ~isempty(cal_master.(fields{ifi}){idx_cal})
                     cal_merged.(fields{ifi}){ical}= cal_master.(fields{ifi}){idx_cal};
                    end
                end
                
            end
            
        end
    end
end