function jTable=set_sortable(h_or_jtable,id)

if isa(h_or_jtable,'matlab.ui.control.Table')
    jScroll = findjobj(h_or_jtable);
    jTable = jScroll.getViewport.getView;
else
    jTable=h_or_jtable;
end


jTable.setSortable(id);		% or: set(jtable,'Sortable','on');
jTable.setAutoResort(id);
jTable.setMultiColumnSortable(id);
jTable.setPreserveSelectionsAfterSorting(id);