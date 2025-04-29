<?php

namespace App\Http\Controllers;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\News;
use Illuminate\Support\Facades\Http;

class NewsController extends Controller
{

    public function getNews(){
        return News::all();
    }

    public function generateLatestNews(){

        $baseUrl = 'https://newsapi.org/v2';
        $url = $baseUrl.'/everything?q=Malaysia&from='.now()->subDays(2)->format('Y-m-d').'&sortBy=publishedAt&apiKey='.env('NEWS_API_KEY');
        
        try {
            $response = Http::withOptions([
                'verify' => 'C:\laragon\etc\ssl\cacert.pem'
            ])->get($url);
            
            $data = $response->json();
            News::where('publishedAt', '<',now()->subDays(2))->delete();
            
            if ($response->successful()) {
                $data = $response->json(); // First, get the JSON data
                
                if (isset($data['articles'])) {
                    foreach ($data['articles'] as $article) {
                        // Check if news with this title already exists
                        $existingNews = News::where('title', $article['title'])->first();
                        
                        if (!$existingNews) {
                            News::create([
                                'title' => $article['title'] ?? null,
                                'description' => $article['description'] ?? null,
                                'author' => $article['author'] ?? null,
                                'url' => $article['url'] ?? null,
                                'urlToImage' => $article['urlToImage'] ?? null,
                                'publishedAt' => $article['publishedAt'] ?? null,
                                // Add other fields as needed
                            ]);
                        }
                    }
            
                    return response()->json([
                        'status' => 'success',
                        'message' => 'News generated successfully',
                        'count' => count($data['articles']) // Optional: show how many articles processed
                    ]);
                }
                
                return response()->json([
                    'status' => 'error',
                    'message' => 'No articles found in response'
                ], 400);
            }

            return response()->json([
                'error' => 'News API request failed',
                'message' => response()->status()
            ], 500);
            
        } catch (\Exception $e) {
            return response()->json([
                'error' => 'News API request failed',
                'message' => $e->getMessage()
            ], 500);
        }
    }
}
