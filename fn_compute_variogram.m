function [sill, range, h, gamma, nPairs, methodName, methodNameShort] = fn_compute_variogram (lats, longs, values, options)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% initial code from Christophe Loth, 09/12/12
% heavily modified by Jack Baker 2/1/2019
% last updated 3/17/2020
% modified by Lukas Bodenmann 04/13/2022: Incorporate MLL
%
% Calculate empirical semivariograms from data, using several fitting
% techniques
% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Input Variables
%   lats = list of site lats
%   longs = list of site longs
%   values = list of the random variable values at each site
%   options.maxR = maximum distance to which the variogram is computed
%   options.binSize = distance interval accounted for by each computed variogram 
%       value
%   options.plotFig = 1 to plot semivariogram, =0 to not
%
% Output Variables
%   h = vector of separation distances (lags)
%   gamma = empirical variogram
%   sill = fitted sill for an exponential variogram model
%   range = fitted range for an exponential variogram model
%   nPairs = number of station pairs with a given separation distance
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% Compute site-to-site distances
nsites=length(lats);
nmax = round(options.maxR/options.binSize);
        
distance = zeros(nsites);
distance_ratio = zeros(nsites);
for i=1:nsites
    for j=1:nsites
        distance(i,j) = pos2dist(lats(i),longs(i),lats(j),longs(j),1); 
        distance_ratio(i,j) = round(distance(i,j)/options.binSize); % To group stations in bins
    end
end


%% compute semivariogram

% initialize variables
h = zeros(nmax,1);
gamma = zeros(nmax,1);     

% compute empirical semivariance
for i=1:nmax
    [site1, site2] = find(distance_ratio == i);
    nPairs(i,1) = length(site1);
    h(i,1)=options.binSize/2+(i-1)*options.binSize;
    gamma(i,1) = (1/(2*(nPairs(i,1))))*sum((values(site1)-values(site2)).*(values(site1)-values(site2)));
end

%% perform fits, using several techniques

[sill, range, ~, methodName, methodNameShort] = fit_vario(h, gamma, nPairs, options);

% MLL method operates directly with long/lat
if any(options.fitMethod==7)
    [sill(end+1), range(end+1), ~, methodName{end+1}, methodNameShort{end+1}] = fit_MLL(lats, longs, values, options);

% Plot the results
if options.plotFig
    hPlot = 0:0.5:options.maxR; % use a finer distance resolution for plotting semivariograms
    legendText{1} = 'Empirical semivariogram';

    hf = figure;
    set(hf, 'Visible', 'off'); % don't show the figure on the screen
    hEmp=plot(h, gamma, '.k', 'linewidth', 2);
    hold on
    for i = 1:length(options.fitMethod)
        if options.funcForm == 1
            h(i) = plot(hPlot, sill(i) * (1-exp(-3.*hPlot./range(i))),options.linespec{i});
        elseif options.funcForm == 2
            h(i) = plot(hPlot, sill(i) * (1-exp(-(hPlot.^0.55)./range(i))),options.linespec{i});
        end
        legendText{i+1} = methodName{i};
    end
    legend(legendText, 'location', 'southeast')
    xlabel('h [km]');
    ylabel('\gamma(h)');
    set(gca, 'xlim', [0 80])
    FormatFigureBook
end

end