function [f, fftt, ts] = DFT(FS, senal)
% DISCRET FOURIER TRANSFORM
% -------------------------------------------------------------------
% DFT: Determina la Transformada discreta de Fourier de una se�al
%       discreta
%       f = Vector de frecuencias
%       fftt = Fast Fourier Transform de la se�al
%       ts = vector de tiempo de la se�al
% -------------------------------------------------------------------

% Intervalo de tiempo
dt = 1 / FS;

% Tama�o de la se�al
N = length(senal);
L = dt * N;

% Numero de elementos de la se�al
Nfft = 2^nextpow2(N);

% Vector de frecuencia
df = FS / Nfft;
fn = FS / 2; % Nyquist cut-off frequency
f = -fn:df:fn - df;

% Vector de tiempo
ts = 0:dt:L - dt;
ts = ts';

% FAST FOURIER TRANSFORM
fftt = fft(senal, Nfft) ./ Nfft;

end