fc = 24e9;          % Frecuencia de portadora
c = 3e8;            % Velocidad de la luz

N = 4096;           % Longitud DFT
fs = 44100;         % Frecuencia muestreo
M = 1;              % Factor de diezmado

vMax = 0;           % Inicializacion de la velocidad maxima
fMax = 0;           % Inicializacion de la frecuencia doppler maxima

lector = audioDeviceReader;         % Configuracion de tarjeta de sonido como muestreador y digitalizador de señal
lector.SamplesPerFrame = N;
lector.SampleRate = fs;

setup(lector)
disp('Micro listo')

%x1 = ( (-N/2):(N/2-1) )* fs/N;                        %FFT ta  555l cual
x2 = ( (-N/(2*M)):(N/(2*M)-1) )* fs/(M*N);            %FFT tras diezmado

figure

tic
while toc < 120
    
    data = lector();
    dataDiez = decimate(data, M);
    
    
    %y1 = 10*log10(abs(fftshift(fft(data))));    
    y2 = 10*log10(abs(fftshift(fft(dataDiez))));
    
    
    [mx, I] = max(y2);
    if abs(x2(I)) > fMax && mx > 15
        fMax = abs(x2(I));
        vMax = fMax/2*c/fc;
    end
    
    
    disp(['Velocidad maxima: ', num2str(vMax), 'm/s = ', num2str(vMax*3.6), 'km/h'])
    
    plot(x2,y2);
    axis([-fs/(2*M^2) fs/(2*M^2) 5 40]);
    drawnow
    
    
end

disp('Fin del programa.')
release(lector)