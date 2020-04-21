function [mu, sigma, values] = sigma_clipping(values, varargin)
   
    import util.text.*;
    import util.stat.*;
    
    if nargin<1
        fprintf('usage: [mu,sigma] = sigma_clipping(values, varargin)\n');
        fprintf('--Options: nsigma, iterations, distribution, plotting, axis, pause\n');
        return;
    end
    
    % add input checks on "values"
    values = values(:);
    values(isnan(values)) = [];
    
    Nsigma = 5;
    Niter_max = 5;
    dist = 'gauss';
    use_plot = 0;
    ax = [];
    pause_length = 0;
    
    for ii = 1:2:length(varargin)
        key = varargin{ii};
        val = varargin{ii+1};
        
        if cs(key, {'sigma', 'nsigma', 'num_sigma', 'number sigma'})
            Nsigma = val;
        elseif cs(key, 'iterations')
            Niter_max = val;
        elseif cs(key, 'distribution')
            dist = val;
        elseif cs(key, 'plotting')
            use_plot = parse_bool(val);
        elseif cs(key, {'axis', 'axes'})
            ax = val;
        elseif cs(key, 'pause length')
            pause_length = val;
        end
        
    end
    
    if isempty(ax)
        ax = gca;
    end
    
    values = values(~isnan(values));
    
    mu = median(values, 'omitnan');
%     sigma = fwhm(values);
    sigma = std(values, 'omitnan');
%     N = sum(values>mu-Nsigma*sigma & values<mu+Nsigma*sigma);
    values = values(values>mu-Nsigma*sigma & values<mu+Nsigma*sigma);
    N = numel(values);
    
    if isnan(mu)
        return; % silently give back a NaN if the inputs are all NaN!
    end
    
    for ii = 1:Niter_max
        
        mu_prev = mu;
        sigma_prev = sigma;
        N_prev = N;
        
        if cs(dist, 'gauss')
%             phat = mle(values, 'logpdf', @(x,m,s) -0.5*log(2*pi*s.^2) -0.5*(x-m).^2/s.^2, 'start', [mu_prev,sigma_prev],...
%                 'LowerBound',[mu_prev-Nsigma*sigma_prev, 0], 'UpperBound', [mu_prev+Nsigma*sigma_prev, Nsigma*sigma_prev]);
            phat = fitdist(values, 'normal');
            mu = phat.mu;
            sigma = phat.sigma;
        elseif cs(dist, {'weibull', 'max values'})
            phat = evfit(-double(values)); 
            
            mu = -phat(1);
            sigma = phat(2);
        end
        
        
        if use_plot
            disp(['plotting iteration ' num2str(ii)]);
            step = (max(values)-min(values))/sqrt(N);
            if all(values==round(values)) && step<1
                step = 1;
            end
                
            x = min(values):step:max(values);
            x2 = min(values):step/4:max(values);
            histogram(ax, values, x);
            
            if cs(dist, 'gauss')
                line(ax, x2, step*N*1/sqrt(2*pi*sigma.^2)*exp(-0.5*((x2-mu)/sigma).^2), 'color', 'red');
            elseif cs(dist, {'weibull', 'max values'})
                line(ax, x2, step*N*evpdf(-x2, -mu, sigma), 'color', 'red');
            end
            
            pause(pause_length);
            
        end
        
        values = values(values>mu-Nsigma*sigma & values<mu+Nsigma*sigma);
                
        N = numel(values);        
        
        if N==N_prev || N<4
            break;
        end
        
    end
        
end