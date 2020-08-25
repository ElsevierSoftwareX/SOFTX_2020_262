
function update_wc_fig(ip)

esp3_obj = getappdata(groot,'esp3_obj');
wc_fan  = getappdata(esp3_obj.main_figure,'wc_fan');
if isempty(wc_fan)
    return;
end

curr_disp = esp3_obj.curr_disp;
layer=get_current_layer();


[trans_obj,~]=layer.get_trans(curr_disp);

data = trans_obj.Data.get_subdatamat('field',curr_disp.Fieldname,'idx_ping',ip);

amp = squeeze(data);

if isempty(amp)
    return;
end

r = trans_obj.get_transceiver_range();

beamAngle=trans_obj.get_params_value('BeamAngleAthwartship',ip,1:size(data,2));

if numel(beamAngle)>1
    
    
    sampleAcrossDist = r*tand(beamAngle');
    sampleUpDist = r*cosd(beamAngle');
    
    cax = curr_disp.Cax;
    
    idx_keep = amp>cax(1);
    % display WC data itself
    set(wc_fan.wc_gh,...
        'XData',sampleAcrossDist,...
        'YData',sampleUpDist,...
        'ZData',zeros(size(amp)),...
        'CData',amp,...
        'AlphaData',idx_keep);
    
    if all(idx_keep(:)==0)
        idx_keep = true(size(idx_keep));
    end
    
    xlim = [-max(abs(sampleAcrossDist(:))) max(abs(sampleAcrossDist(:)))];
    ylim = [0 nanmax(sampleUpDist(:))];
    ylim(1) = nanmax(ylim(1),curr_disp.R_disp(1));
    ylim(2) = nanmin(ylim(2),curr_disp.R_disp(2));
    
    set(wc_fan.wc_axes,...
        'XLim',xlim,...
        'Ylim',ylim,...
        'Clim',esp3_obj.curr_disp.Cax,...
        'Layer','top','Visible','on');
else
    wc_fan.wc_axes.Visible='off';
end


fname = list_layers(layer);
[~,fnamet,~] = fileparts(fname{1});
tt = sprintf('File: %s. Ping: %.0f/%.0f. Time: %s.',fnamet,ip,numel(trans_obj.Time),datestr(trans_obj.get_transceiver_time(ip),'HH:MM:SS'));
wc_fan.wc_axes_tt.String = tt;

end