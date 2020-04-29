function update_echo_int_alphamap(main_figure)

curr_disp=get_esp3_prop('curr_disp');
echo_int_tab_comp=getappdata(main_figure,'EchoInt_tab');

if ~isempty(echo_int_tab_comp.main_plot.UserData)
    switch echo_int_tab_comp.main_plot.UserData
        case 'nb_samples'
            cd=echo_int_tab_comp.main_plot.CData(echo_int_tab_comp.main_plot.CData>0);
            if ~isempty(cd)
                cax=[prctile(cd(:),5) prctile(cd(:),95)];
            else
                cax=[0 1];
            end
        case 'prc'
            cax=[0 100];
        case {'nb_st_tracks' 'tag'}
            cd=echo_int_tab_comp.main_plot.CData;
            cax=[nanmin(cd(:)) nanmax(cd(:))];
            
        otherwise
            cax=curr_disp.getCaxField(echo_int_tab_comp.main_plot.UserData);
    end
    
    if cax(2)<=cax(1)
        cax(2)=cax(1)+1;
    end
    
    alpha_data= echo_int_tab_comp.main_plot.CData>cax(1);
    
    set(echo_int_tab_comp.main_ax,'Clim',cax);
    set(echo_int_tab_comp.main_plot,'alphadata',alpha_data);
end

end