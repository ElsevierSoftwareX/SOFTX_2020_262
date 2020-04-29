function data=reorder_ping(data)

for ii=length(data.pings)
    time=data.pings(ii).time;
    
    if ~issorted(time)
        idx_sort=sort(time);
        
        N=length(time);
        data.pings(ii)=structfun(@(x) reorder(x,N,idx_sort),data.pings(ii),'un',0);
        data.params(ii)=structfun(@(x) reorder(x,N,idx_sort),data.params(ii),'un',0);
        
    end
    
end
end

function y=reorder(x,N,idx_sort)
if size(x,2)==N
    y=x(:,idx_sort);
else
    y=x;
end
end