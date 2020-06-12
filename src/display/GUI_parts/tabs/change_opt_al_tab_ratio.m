function change_opt_al_tab_ratio(src,evt)

curr_fig = ancestor(src,'figure');

switch curr_fig.SelectionType
    
    case 'open'
        
        curr_disp = get_esp3_prop('curr_disp');
        
        switch src.Tag
            case 'algo'
                if curr_disp.Al_opt_tab_size_ratio <= 0.9
                    curr_disp.Al_opt_tab_size_ratio = 0.98;
                else
                    curr_disp.Al_opt_tab_size_ratio = 0.6;
                end
            case 'opt'
                if curr_disp.Al_opt_tab_size_ratio <= 0.1
                    curr_disp.Al_opt_tab_size_ratio = 0.6;
                else
                    curr_disp.Al_opt_tab_size_ratio = 0.02;
                end
        end
end