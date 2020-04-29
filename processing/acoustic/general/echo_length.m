% length of the bottom echo along the axis (in m), given:
%   r_p: range of pulse (c*tau/2) (in m)
%   theta_b: beam aperture (in degrees)
%   beta: incident angle at bottom (combining seafloor slope and transducer tilt) (in degrees)
%   r: range of the start of the echo (bottom range) (in m)
%
% example use:
% r_p=1e-3*1500/2; theta_b=7; beta=0:0.1:5; r=100;
% figure();plot(beta,echo_length(r_p,theta_b,beta,r));grid on;
% xlabel('angle(deg.)');ylabel('Echo length (m)');

function el = echo_length(r_p,theta_b,beta,r)

beta = abs(beta);

if beta < theta_b/2
    % when incident angle is smaller than half aperture, the reflection
    % starts within the footprint of the aperture on the seafloor, and so
    % the echo starts here and finishes at the far edge of the aperture.
    
    el = r_p + r.*( 1./cosd(beta+theta_b/2) - 1);
    
elseif (beta >= theta_b/2) && (beta < (180/2 - theta_b/2))
    % when incident angle is larger than half aperture, the bottom
    % reflection starts outside of the footprint of the aperture on the
    % seafloor, so that the echo starts at one edge of the aperture and
    % finishes at the other edge.
    
    el = r_p + r.*( cosd(beta-theta_b/2)./cosd(beta+theta_b/2) - 1);
    
else
    % when incident angle is so large that at the far edge, the seabed
    % doesn't intersect aperture, then no gemotrical end to echo.
    el = Inf;
    
end


end