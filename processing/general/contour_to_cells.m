function [c_out,l_out]=contour_to_cells(C,L)

idx=find(ismember(C(1,:),L)&(abs(C(2,:))-C(2,:))==0);

c_out=cell(1,numel(idx));
l_out=C(1,idx);
nb_elt=C(2,idx);

for i_el=1:numel(idx)
    idx_el=(idx(i_el)+1):(idx(i_el)+nb_elt(i_el));
    c_out{i_el}=[C(1,idx_el);C(2,idx_el)];
end


