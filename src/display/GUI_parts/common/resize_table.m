
function resize_table(src,~)
table=findobj(src,'Type','uitable');

if~isempty(table)

    column_width=table.ColumnWidth;
    pos_f=getpixelposition(table);
    if iscell(column_width)
        width_t_old=nansum([column_width{:}]);
        width_t_new=pos_f(3);
        new_width=cellfun(@(x) x/width_t_old*width_t_new,column_width,'un',0);
        set(table,'ColumnWidth',new_width);
    end
end

end
