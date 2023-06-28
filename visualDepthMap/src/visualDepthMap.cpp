#include <opencv2/core.hpp>
#include <opencv2/imgcodecs.hpp>
#include <opencv2/highgui.hpp>
#include <iostream>

#include <vector>
#include <conio.h>
#include <SpectralRadar.h>

using namespace cv;
using namespace std;

#include <iostream>


void ExportDataAndImage()
{
	char message[1024];

	OCTDeviceHandle Dev = initDevice();
	ProbeHandle Probe = initProbe(Dev, "Probe_Standard_OCTG_LSM03.ini");
	//ProbeHandle Probe = initProbe(Dev, "Probe");
	ProcessingHandle Proc = createProcessingForDevice(Dev);

	RawDataHandle Raw = createRawData();
	DataHandle BScan = createData();
	ColoredDataHandle VideoImg = createColoredData();


	if (getError(message, 1024))
	{
		cout << "ERROR: " << message << endl;
		(void)getchar();
		return;
	}


	getNumberOfDevicePresetCategories(Dev);

	// The scan speed of SD-OCT systems can be changed. A better image quality can be obtained with a longer integration time and therefore lower scan speed.
	// Preset 0 is the default scan speed followed by the highest. Please note to adjust the reference intensity on your scanner manually.
	// The number of available device presets can be obtained with #getNumberOfDevicePresets and the description of each preset with #getDevicePresetDescription
	int NumberOfDevicePresets = getNumberOfDevicePresets(Dev, 0);
	cout << getDevicePresetDescription(Dev, 0, 0) << endl;
	setDevicePreset(Dev, 0, Probe, Proc, 0);


	double startX = -2.5;
	double startY = -1.0;
	double stopX = 3.0;
	double stopY = -1.0;

	ScanPatternHandle Pattern = createBScanPatternManual(Probe, startX, startY, stopX, stopY, 1024);

	startMeasurement(Dev, Pattern, Acquisition_AsyncFinite);

	getRawData(Dev, Raw);
	getCameraImage(Dev, VideoImg);
	

	setProcessedDataOutput(Proc, BScan);
	executeProcessing(Proc, Raw);

	stopMeasurement(Dev);

	//// Exports the processed data to a csv-file to the specified folder. Several different export formats are available, see #DataExportFormat
	//exportData(BScan, DataExportFormat::DataExport_CSV, "C:\\test_oct_data_9.csv");

	//// The unprocessed data from the detector in #RawDataHandle can be exported as well, here to a binary raw/srm file
	//exportRawData(Raw, RawDataExportFormat::RawDataExport_RAW, "C:\\test_raw_data_raw9.raw");
	//exportRawData(Raw, RawDataExportFormat::RawDataExport_SRR, "C:\\test_raw_data_srr9.txt");

	// The OCT image can be exported as an image in common image format as well. It needs to be colored for that, e.g. the colormap and boundaries for the coloring need to be defined.
	// #ColoringHandle with specified #ColorScheme, here simple black and white, and #ColoringByteOrder
	ColoringHandle Coloring = createColoring32Bit(ColorScheme_BlackAndWhite, Coloring_RGBA);
	// set the boundaries for the colormap, 0.0 as lower and 70.0 as upper boundary are a good choice normally.
	setColoringBoundaries(Coloring, 0.0, 70.0);
	// Exports the processed data to an image with the specified slice normal direction since this will result in 2D-images.
	// To get the B-scan in one image with depth and scan field as axes for a single B-scan #Direction_3 is chosen.
	exportDataAsImage(BScan, Coloring, ColoredDataExport_JPG, Direction_3, "C:\\Ajay_OCT\\visualDepthMap\\data\\oct.jpg", ExportOption_DrawScaleBar | ExportOption_DrawMarkers | ExportOption_UsePhysicalAspectRatio);
	// Save video camera image
	// Convert ColoredDataHandle to OpenCV Mat
	// access image data

	std::chrono::seconds(1);
	visualizeScanPatternOnImage(Probe, Pattern, VideoImg);
	
	unsigned long * data = getColoredDataPtr(VideoImg);
	int width = 648;
	int height = 484;

	// Convert and export the image
	cv::Mat cvImage = cv::Mat(height, width, CV_8UC3);
	for (int i = 0; i < height; i++) {
		for (int j = 0; j < width; j++) {
			unsigned long pixelValue = data[i * width + j];
			cv::Vec3b& pixel = cvImage.at<cv::Vec3b>(i, j);
			pixel[0] = (pixelValue >> 16) & 0xFF; // Blue channel
			pixel[1] = (pixelValue >> 8) & 0xFF;  // Green channel
			pixel[2] = pixelValue & 0xFF;         // Red channel
		}
	}

	cv::imshow("Image", cvImage);
	cv::waitKey(0);
	//cv::imwrite("C:\\Ajay_OCT\\visualDepthMap\\data\\scanPattern.jpg", cvImage);


	// TODO: warum nicht .srm?

	if (getError(message, 1024))
	{
		cout << "ERROR: " << message << endl;
		_getch();
		return;
	}

	clearScanPattern(Pattern);

	clearData(BScan);
	clearRawData(Raw);
	clearColoredData(VideoImg);

	clearProcessing(Proc);
	closeProbe(Probe);
	closeDevice(Dev);

	_getch();
}


int main(){
    cout << "Live stream of B-Scan: " << endl;

    //BScanLiveStream();
    ExportDataAndImage();

	return 0;
}

// Run program: Ctrl + F5 or Debug > Start Without Debugging menu
// Debug program: F5 or Debug > Start Debugging menu

// Tips for Getting Started: 
//   1. Use the Solution Explorer window to add/manage files
//   2. Use the Team Explorer window to connect to source control
//   3. Use the Output window to see build output and other messages
//   4. Use the Error List window to view errors
//   5. Go to Project > Add New Item to create new code files, or Project > Add Existing Item to add existing code files to the project
//   6. In the future, to open this project again, go to File > Open > Project and select the .sln file






