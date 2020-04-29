function [pdf,x_mat,y_mat]=pdf_2d_perso(X,Y,N_x,N_y,win)

if isscalar(N_x)
    maxi_x=nanmax(X(:));
    mini_x=nanmin(X(:));
    dx=(maxi_x-mini_x)/N_x;
    x=linspace(mini_x,maxi_x,N_x);
else
    x=N_x;
    dx=abs(nanmean(diff(x)));
    N_x=numel(x);
end

if isscalar(N_y)
    maxi_y=nanmax(Y(:));
    mini_y=nanmin(Y(:));
    dy=(maxi_y-mini_y)/N_y;
    y=linspace(mini_y,maxi_y,N_y);
else
    y=N_y;
    dy=abs(nanmean(diff(y)));
    N_y=numel(y);
end


pdf=zeros(N_x,N_y);


vec_X=X(~isnan(X)&~isnan(Y));
vec_Y=Y(~isnan(Y)&~isnan(X));


w_tot=length(vec_X)*length(vec_Y);

if strcmp(win,'box')
    for i=1:N_x
        for j=1:N_y
            idx_bin=((vec_X-x(i))/dx<=1/2&(vec_X-x(i))/dx>-1/2)&((vec_Y-y(j))/dy<=1/2&(vec_Y-y(j))/dy>-1/2);
            pdf(i,j)=sum(idx_bin)/(dx*dy*w_tot);
        end
        
    end
elseif strcmp(win,'gauss')
    for i=1:N_x
        parz_win_x=1/(dx*sqrt(2*pi))*exp(-(vec_X-x(i)).^2/(2*dx^2));
        for j=1:N_y
            parz_win_y=1/(dy*sqrt(2*pi))*exp(-(vec_Y-y(j)).^2/(2*dy^2));
            pdf(i,j)=sum(parz_win_x.*parz_win_y);
        end
    end
end

pdf=double(pdf/nansum(pdf(:)*dx*dy));
x_mat=repmat(x(:),1,N_y);
y_mat=repmat(y(:)',N_x,1);
end