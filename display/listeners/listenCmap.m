function listenCmap(src,evt,main_figure)

disp_perso(main_figure,sprintf('Changing colormap to %s',evt.AffectedObject.Cmap));
update_cmap(main_figure);
hide_status_bar(main_figure);
end

