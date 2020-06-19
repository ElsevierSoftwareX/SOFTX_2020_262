function change_opt_al_tab_ratio(src,evt)

curr_fig = ancestor(src,'figure');

dx = 0.2;

switch curr_fig.SelectionType
    
    case 'open'
        
        curr_disp = get_esp3_prop('curr_disp');
        
        switch src.Tag
            case 'algo'
                if curr_disp.Al_opt_tab_size_ratio == 1-dx
                    curr_disp.Al_opt_tab_size_ratio = 0.5;
                else
                    curr_disp.Al_opt_tab_size_ratio = 1-dx;
                end
            case 'opt'
                if curr_disp.Al_opt_tab_size_ratio == dx
                    curr_disp.Al_opt_tab_size_ratio = 0.5;
                else
                    curr_disp.Al_opt_tab_size_ratio = dx;
                end
        end
end