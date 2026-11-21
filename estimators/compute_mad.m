% COMPUTE_MAD Vectorized Robust Scale Estimator for Real and Complex Signals
%
% Usage:
%   s_hat = compute_mad(y)
%   s_hat = compute_mad(y, dim)
%
% Inputs:
%   y   - Input vector or 2D matrix (real or complex)
%   dim - Operating dimension (default: 1)
%
% Output:
%   s_hat - Scale estimate asymptotically consistent with standard deviation

function s_hat = compute_mad(y, dim)
    if nargin < 2
        if isvector(y)
            dim = find(size(y) > 1, 1);
            if isempty(dim), dim = 1; end
        else
            dim = 1;
        end
    end

    Cn = 1.4826; % Normal consistency factor

    if isreal(y)
        % Real-valued estimation
        y_med = median(y, dim);
        s_hat = Cn * median(abs(y - y_med), dim);
    else
        % Complex baseband estimation: evaluate orthogonal I and Q channels
        y_r = real(y);
        y_i = imag(y);

        med_r = median(y_r, dim);
        med_i = median(y_i, dim);

        s_r = Cn * median(abs(y_r - med_r), dim);
        s_i = Cn * median(abs(y_i - med_i), dim);

        % Combine orthogonal power components
        s_hat = sqrt(s_r.^2 + s_i.^2);
    end
end