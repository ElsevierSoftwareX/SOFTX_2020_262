function figure_size = get_dlg_position(parentHandle,figure_size, figure_units,which_screen)

fig_destinationUnits = figure_units;

if isempty(parentHandle)
    parentHandle=gcbf;
end

if ~isempty(parentHandle)
    s_temp = get(groot,'MonitorPositions');
    id_m_screen=get_fig_screen_id(parentHandle);
    switch which_screen
        case 'other'
            nb_screens=size(s_temp,1);
            if nb_screens>1
                tmp=setdiff(1:nb_screens,id_m_screen);
                id_screen=tmp(end);
            else
                id_screen=id_m_screen;
            end
        otherwise
            id_screen=id_m_screen;
    end
else
    s_temp = get(groot,'MonitorPositions');
    id_screen=1;
end

fig_size = s_temp(id_screen,:);
fig_sourceUnits = get(groot,'Units');


fig_hFig = figure('visible','off','units',fig_sourceUnits);
fig_hFig.Position=fig_size;


c = onCleanup(@() close(fig_hFig));

container_size = hgconvertunits(fig_hFig, fig_size ,...
    fig_sourceUnits, fig_destinationUnits, get(fig_hFig,'Parent'));

delete(c);

figure_size(1) = container_size(1)  + 1/2*(container_size(3) - figure_size(3));
figure_size(2) = container_size(2)  +  2/3*(container_size(4) - figure_size(4));


